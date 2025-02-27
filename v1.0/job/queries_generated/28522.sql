WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 3
),
DetailedMovieInfo AS (
    SELECT 
        tr.title,
        tr.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT p.info ORDER BY p.info) AS person_info
    FROM 
        TopRankedMovies tr
    LEFT JOIN 
        aka_title at ON tr.title_id = at.movie_id
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
    LEFT JOIN 
        movie_companies mc ON tr.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tr.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON tr.title_id = cc.movie_id
    LEFT JOIN 
        person_info p ON cc.subject_id = p.person_id
    GROUP BY 
        tr.title, tr.production_year, tr.cast_count
)
SELECT 
    title,
    production_year,
    cast_count,
    aka_names,
    company_names,
    keywords,
    person_info
FROM 
    DetailedMovieInfo
ORDER BY 
    production_year DESC,
    cast_count DESC;
