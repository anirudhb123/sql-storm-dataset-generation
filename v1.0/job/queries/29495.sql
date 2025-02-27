WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
FilteredMovies AS (
    SELECT 
        rm.*, 
        ct.kind AS company_type,
        cn.name AS company_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast_members,
    fm.aka_names,
    fm.associated_keywords,
    fm.company_name,
    fm.company_type
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast_members DESC;