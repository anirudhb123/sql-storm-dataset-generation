
WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        type.kind AS title_type,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    JOIN 
        kind_type type ON a.kind_id = type.id
    WHERE 
        a.production_year IS NOT NULL
),
PopularMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        LISTAGG(DISTINCT p.name, ', ') AS cast_members,
        MAX(t.title) AS title,
        MAX(t.production_year) AS production_year
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        c.movie_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
HighRatedMovies AS (
    SELECT 
        i.movie_id,
        LISTAGG(DISTINCT inf.info, ', ') AS movie_info
    FROM 
        movie_info i
    JOIN 
        info_type inf ON i.info_type_id = inf.id
    WHERE 
        inf.info ILIKE '%award%' OR inf.info ILIKE '%rating%'
    GROUP BY 
        i.movie_id
)
SELECT 
    rt.title AS title,
    rt.production_year,
    rt.title_type,
    pm.num_cast_members,
    pm.cast_members,
    hm.movie_info
FROM 
    RankedTitles rt
LEFT JOIN 
    PopularMovies pm ON rt.title_id = pm.movie_id
LEFT JOIN 
    HighRatedMovies hm ON rt.title_id = hm.movie_id
WHERE 
    rt.rank <= 10
ORDER BY 
    rt.production_year DESC, 
    pm.num_cast_members DESC;
