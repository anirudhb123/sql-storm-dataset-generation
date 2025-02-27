
WITH MovieTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ct.kind AS company_type,
        c.name AS company_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.id, t.title, t.production_year, t.imdb_index, ct.kind, c.name
),
CastInfo AS (
    SELECT 
        ca.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(*) AS num_cast
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id
),
FinalBenchmark AS (
    SELECT 
        mti.title_id,
        mti.title,
        mti.production_year,
        mti.imdb_index,
        mti.keywords,
        ci.cast_names,
        ci.num_cast,
        mti.company_name,
        mti.company_type
    FROM 
        MovieTitleInfo mti
    LEFT JOIN 
        CastInfo ci ON mti.title_id = ci.movie_id
)
SELECT 
    fb.title AS Movie_Title,
    fb.production_year AS Production_Year,
    fb.keywords AS Movie_Keywords,
    fb.cast_names AS Cast_List,
    fb.company_name AS Production_Company,
    fb.company_type AS Company_Type
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC,
    fb.title ASC;
