
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        COUNT(mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
CastStats AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
TrendMovies AS (
    SELECT 
        md.title_id, 
        md.title, 
        md.production_year, 
        cs.total_cast, 
        md.company_count,
        md.company_names,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY cs.total_cast DESC) AS rank_within_year
    FROM 
        MovieDetails md
    JOIN 
        CastStats cs ON md.title_id = cs.movie_id
    WHERE 
        md.production_year >= 2000
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.total_cast, 
    tm.company_count, 
    tm.company_names
FROM 
    TrendMovies tm
WHERE 
    tm.rank_within_year <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
