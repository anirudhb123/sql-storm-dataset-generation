
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS title_kind,
        COUNT(c.movie_id) AS cast_members,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_cast
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    LEFT JOIN 
        name p ON an.person_id = p.imdb_id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),

TopRatedMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS companies,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name an ON mc.company_id = an.id
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT an.name) > 1 
),

MovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.title_kind,
        rt.cast_members,
        rt.female_cast,
        rt.male_cast,
        tm.companies,
        tm.keyword_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        TopRatedMovies tm ON rt.title_id = tm.movie_id
)

SELECT 
    md.title AS "Title",
    md.production_year AS "Production Year",
    md.title_kind AS "Kind",
    md.cast_members AS "Total Cast",
    md.female_cast AS "Female Cast",
    md.male_cast AS "Male Cast",
    COALESCE(md.companies, 'No companies') AS "Production Companies",
    COALESCE(md.keyword_count, 0) AS "Keyword Count"
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
