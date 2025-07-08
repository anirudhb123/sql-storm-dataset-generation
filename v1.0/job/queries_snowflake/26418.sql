
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        LISTAGG(n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cd.cast_names, 'No Cast') AS cast_names,
        COALESCE(cd.cast_count, 0) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        CastDetails cd ON t.id = cd.movie_id
)
SELECT 
    r.aka_name, 
    md.title, 
    md.production_year, 
    md.cast_names, 
    md.cast_count
FROM 
    RankedTitles r
JOIN 
    MovieDetails md ON r.title_id = md.movie_id
WHERE 
    r.title_rank = 1 
ORDER BY 
    md.production_year DESC;
