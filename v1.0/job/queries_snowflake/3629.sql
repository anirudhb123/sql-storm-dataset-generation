
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        RANK() OVER (PARTITION BY title.kind_id ORDER BY title.production_year DESC) AS rank
    FROM title
    INNER JOIN aka_title ON title.id = aka_title.movie_id
    WHERE title.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM RankedMovies
    WHERE rank <= 5
),
MovieKeywords AS (
    SELECT 
        movie_id,
        LISTAGG(keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_id
),
CastRoles AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM cast_info ci
    INNER JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, ci.person_id, rt.role
),
FilteredCast AS (
    SELECT 
        movie_id,
        person_id,
        role,
        role_count
    FROM CastRoles
    WHERE role_count > 1
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
FinalOutput AS (
    SELECT 
        tm.title AS movie_title,
        tm.production_year,
        mk.keywords,
        fc.person_id,
        fc.role,
        ci.company_name,
        ci.company_type
    FROM TopMovies tm
    LEFT JOIN MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN FilteredCast fc ON tm.movie_id = fc.movie_id
    LEFT JOIN CompanyInfo ci ON tm.movie_id = ci.movie_id
)
SELECT 
    movie_title,
    production_year,
    COALESCE(keywords, 'No Keywords') AS keywords,
    COALESCE(role, 'No Role') AS role,
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type
FROM FinalOutput
ORDER BY production_year DESC, movie_title;
