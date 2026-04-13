from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List
import os

from . import models, database, auth, git_service

# Création des tables
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="Git Universitaire API")

# Endpoints d'authentification

@app.post("/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer", "role": user.role, "username": user.username}

# Endpoints Dépôts

@app.get("/repositories", response_model=List[dict])
async def get_repositories(current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    if current_user.role == models.UserRole.ADMIN or current_user.role == models.UserRole.TEACHER:
        repos = db.query(models.Repository).all()
    else:
        repos = db.query(models.Repository).filter(models.Repository.owner_id == current_user.id).all()
    
    return [
        {"id": r.id, "name": r.name, "description": r.description, "path": r.path}
        for r in repos
    ]

@app.get("/repositories/{repo_id}/tree")
async def get_repository_tree(repo_id: int, path: str = "", current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    repo = db.query(models.Repository).filter(models.Repository.id == repo_id).first()
    if not repo:
        raise HTTPException(status_code=404, detail="Repository not found")
    
    # Sécurité: Vérifier si l'utilisateur a accès au dépôt
    if current_user.role == models.UserRole.STUDENT and repo.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this repository")

    # Calculer le chemin réel (les dépôts sont dans /home/git/repos dans les scripts originaux)
    # Pour le dev local, on va adapter.
    return git_service.GitService.get_repo_tree(repo.path, path)

@app.get("/repositories/{repo_id}/file")
async def get_repository_file(repo_id: int, path: str, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    repo = db.query(models.Repository).filter(models.Repository.id == repo_id).first()
    if not repo:
        raise HTTPException(status_code=404, detail="Repository not found")
    
    content = git_service.GitService.get_file_content(repo.path, path)
    return {"content": content}

# Montage du frontend (doit être fait à la fin pour ne pas masquer les routes API)
# Supposon que le frontend est dans ../../frontend relatif à ce fichier
frontend_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "frontend"))
app.mount("/", StaticFiles(directory=frontend_path, html=True), name="frontend")
