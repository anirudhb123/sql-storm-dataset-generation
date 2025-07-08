
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS all_actors
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
QualifiedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.all_actors,
        ROW_NUMBER() OVER (ORDER BY rm.total_cast DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    qm.movie_id,
    qm.title,
    qm.production_year,
    qm.total_cast,
    qm.all_actors
FROM 
    QualifiedMovies qm
WHERE 
    qm.rank <= 10
ORDER BY 
    qm.total_cast DESC;
