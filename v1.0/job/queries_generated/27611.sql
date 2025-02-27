WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
PersonDetails AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY LENGTH(ak.name) DESC) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
),
FilteredMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        RC.actor_name,
        RC.movie_keyword,
        RC.production_year
    FROM 
        title 
    JOIN 
        RankedTitles RC ON title.id = RC.movie_id 
    WHERE 
        RC.title_rank = 1
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_name,
    fm.movie_keyword
FROM 
    FilteredMovies fm
WHERE 
    EXISTS (
        SELECT 1
        FROM person_info pi
        WHERE pi.person_id IN (
            SELECT person_id FROM cast_info ci WHERE ci.movie_id = fm.movie_id
        ) 
        AND pi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Bio'
        )
    )
ORDER BY 
    fm.production_year DESC,
    LENGTH(fm.actor_name) DESC;
