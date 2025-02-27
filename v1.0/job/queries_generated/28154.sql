WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5  -- Only top 5 movies per production year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ', ') AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    cd.cast_names,
    cd.cast_count,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
LEFT JOIN 
    CastDetails cd ON tm.title_id = cd.movie_id
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;
