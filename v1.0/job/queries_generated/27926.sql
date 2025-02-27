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
        t.id, t.production_year
), 
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),
MoviesWithCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    t.title,
    t.production_year,
    m.cast_names,
    m.roles,
    t.keyword_count
FROM 
    TopRankedTitles t
JOIN 
    MoviesWithCast m ON t.title_id = m.movie_id
ORDER BY 
    t.production_year DESC, 
    t.keyword_count DESC;
