WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
RankedTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    rt.aka_names,
    rt.keywords
FROM 
    RankedTitles rt
WHERE 
    rt.rank <= 10
ORDER BY 
    rt.rank;
