import os
import subprocess
from typing import List, Dict, Any

class GitService:
    @staticmethod
    def get_repo_tree(repo_path: str, sub_path: str = "") -> List[Dict[str, Any]]:
        """
        Récupère l'arborescence d'un dépôt Git pour un chemin donné.
        """
        # Utilisation de 'git ls-tree' pour plus de performance et de fiabilité
        # Si sub_path est vide, on prend la racine
        target = "HEAD"
        if sub_path:
            target = f"HEAD:{sub_path}"
        
        try:
            result = subprocess.run(
                ["git", "ls-tree", "-l", target],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            
            tree = []
            for line in result.stdout.splitlines():
                if not line: continue
                # Format: mode type object_hash size	name
                parts = line.split(maxsplit=4)
                if len(parts) < 5: continue
                
                mode, obj_type, obj_hash, size, name = parts
                
                # Nettoyer le nom si c'est un chemin
                clean_name = os.path.basename(name)
                
                tree.append({
                    "name": clean_name,
                    "type": obj_type, # 'blob' ou 'tree'
                    "size": size if size != "-" else 0,
                    "path": os.path.join(sub_path, clean_name).replace("\\", "/")
                })
            return sorted(tree, key=lambda x: (x['type'] != 'tree', x['name']))
        except Exception as e:
            print(f"Erreur Git: {e}")
            return []

    @staticmethod
    def get_file_content(repo_path: str, file_path: str) -> str:
        """
        Récupère le contenu d'un fichier dans le dépôt.
        """
        try:
            result = subprocess.run(
                ["git", "show", f"HEAD:{file_path}"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout
        except Exception as e:
            return f"Erreur lors de la lecture du fichier: {e}"
