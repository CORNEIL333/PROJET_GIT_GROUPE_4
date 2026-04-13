from .database import SessionLocal, engine, Base
from . import models, auth
import os
import subprocess

def init():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    # Créer un admin par défaut
    if not db.query(models.User).filter(models.User.username == "admin").first():
        hashed_pw = auth.get_password_hash("admin123")
        admin = models.User(username="admin", hashed_password=hashed_pw, role=models.UserRole.ADMIN)
        db.add(admin)
        print("✅ Utilisateur 'admin' created (admin123)")
    
    # Créer un étudiant par défaut
    if not db.query(models.User).filter(models.User.username == "etudiant").first():
        hashed_pw = auth.get_password_hash("etudiant123")
        student = models.User(username="etudiant", hashed_password=hashed_pw, role=models.UserRole.STUDENT)
        db.add(student)
        print("✅ Utilisateur 'etudiant' created (etudiant123)")

    db.commit()

    # Création d'un dépôt de test local
    test_repo_path = os.path.abspath("./test_repo.git")
    if not os.path.exists(test_repo_path):
        os.makedirs(test_repo_path)
        subprocess.run(["git", "init", "--bare"], cwd=test_repo_path)
        
        # Ajouter du contenu initial (nécessite un clone temporaire)
        temp_clone = os.path.abspath("./temp_clone")
        subprocess.run(["git", "clone", test_repo_path, temp_clone])
        with open(os.path.join(temp_clone, "README.md"), "w") as f:
            f.write("# Projet de Test\nBienvenue dans le dépôt de test.")
        os.makedirs(os.path.join(temp_clone, "src"))
        with open(os.path.join(temp_clone, "src", "main.py"), "w") as f:
            f.write("print('Hello World')")
        
        subprocess.run(["git", "add", "."], cwd=temp_clone)
        subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=temp_clone)
        subprocess.run(["git", "push", "origin", "master"], cwd=temp_clone)
        
        # cleanup avec gestion des fichiers en lecture seule sur Windows
        def remove_readonly(func, path, excinfo):
            import stat
            os.chmod(path, stat.S_IWRITE)
            func(path)

        shutil.rmtree(temp_clone, onerror=remove_readonly)
        print(f"✅ Dépôt de test créé à {test_repo_path}")

    # Enregistrer le dépôt dans la DB pour l'étudiant
    student = db.query(models.User).filter(models.User.username == "etudiant").first()
    if student and not db.query(models.Repository).filter(models.Repository.name == "Projet-L3").first():
        repo = models.Repository(
            name="Projet-L3",
            path=test_repo_path,
            description="Dépôt de test d'arborescence",
            owner_id=student.id
        )
        db.add(repo)
        db.commit()
        print("✅ Dépôt 'Projet-L3' lié à 'etudiant'")

    db.close()

if __name__ == "__main__":
    init()
