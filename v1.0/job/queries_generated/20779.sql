WITH RecursiveMovieInfo AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY mk.keyword) AS kw_rank
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
), 

ActorDetails AS (
    SELECT
        a.name AS actor_name,
        c.nr_order,
        mc.movie_id,
        m.title AS movie_title,
        m.production_year
    FROM
        cast_info c
    INNER JOIN
        aka_name a ON a.person_id = c.person_id
    INNER JOIN
        aka_title m ON m.id = c.movie_id
    WHERE
        c.nr_order <= 3
), 

CompanyDetails AS (
    SELECT
        co.company_id,
        co.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies co
    JOIN
        company_name cn ON co.company_id = cn.id
    JOIN
        company_type ct ON co.company_type_id = ct.id
    WHERE
        cn.country_code IS NOT NULL AND
        cn.country_code != ''
), 

UnionedInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        ad.actor_name,
        cd.company_name,
        cd.company_type
    FROM 
        RecursiveMovieInfo md
    LEFT JOIN 
        ActorDetails ad ON md.movie_id = ad.movie_id
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)

SELECT 
    ui.movie_title,
    ui.production_year,
    STRING_AGG(DISTINCT ui.actor_name, ', ') AS actors,
    COUNT(DISTINCT ui.company_name) AS number_of_companies,
    MAX(CASE WHEN ui.company_type = 'Distributor' THEN ui.company_name ELSE NULL END) AS distributor_name,
    STRING_AGG(DISTINCT COALESCE(ui.keyword, 'Unknown'), ', ') AS keywords
FROM 
    UnionedInfo ui
WHERE 
    ui.movie_title IS NOT NULL
GROUP BY 
    ui.movie_title, ui.production_year
HAVING 
    COUNT(DISTINCT ui.actor_name) > 1
ORDER BY 
    ui.production_year DESC, 
    ui.movie_title ASC
OFFSET 5 ROWS
FETCH NEXT 15 ROWS ONLY;

This SQL query incorporates several advanced techniques, including CTEs for recursive selection, left joins to allow for potential nulls, aggregations with string manipulations, and even counts with specific conditions in the HAVING clause. It grabs a wealth of data about movies, actors, and companies while ensuring that the results are sorted and filtered according to interesting criteria. The use of COALESCE handles potential NULL values creatively, demonstrating obscure SQL handling rules, including NULL logic in string aggregations.
