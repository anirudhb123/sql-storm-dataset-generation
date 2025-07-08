
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CharacterRoles AS (
    SELECT 
        ak.person_id,
        ak.name AS character_name,
        r.role AS role_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ak.person_id, ak.name, r.role
),
TopCharacterRoles AS (
    SELECT 
        character_name,
        role_name,
        movies_count,
        RANK() OVER (PARTITION BY role_name ORDER BY movies_count DESC) AS role_rank
    FROM 
        CharacterRoles
)
SELECT 
    rt.title,
    rt.production_year,
    rt.company_count,
    rt.company_names,
    tcr.character_name,
    tcr.role_name,
    tcr.movies_count
FROM 
    RankedTitles rt
JOIN 
    TopCharacterRoles tcr ON rt.title_id = (
        SELECT 
            ci.movie_id
        FROM 
            cast_info ci
        JOIN 
            aka_name ak ON ci.person_id = ak.person_id
        WHERE 
            ak.name = tcr.character_name
        LIMIT 1
    )
WHERE 
    tcr.role_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.company_count DESC;
