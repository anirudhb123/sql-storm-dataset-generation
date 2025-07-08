
WITH TagStats AS (
    SELECT
        TRIM(REGEXP_SUBSTR(Tags, '[^><]+', 1, seq.seq)) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN
        (SELECT seq4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 1000))) seq
    ON
        seq.seq <= REGEXP_COUNT(Tags, '><') + 1
    WHERE
        PostTypeId = 1
    GROUP BY
        Tag
),
PopularTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagStats
    WHERE
        PostCount > 5
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS Owner
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '30 days'
        AND p.PostTypeId = 1
),
TagPostMapping AS (
    SELECT
        tp.Tag AS PopularTag,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostType,
        rp.Owner
    FROM
        PopularTags tp
    JOIN
        Posts p ON p.Tags ILIKE '%' || tp.Tag || '%'
    JOIN
        RecentPosts rp ON rp.PostId = p.Id
),
FinalResults AS (
    SELECT
        tpm.PopularTag,
        COUNT(tpm.PostId) AS RelatedPostCount,
        LISTAGG(rp.Title, '; ') AS RelatedPostTitles,
        MAX(rp.CreationDate) AS LatestPostDate
    FROM
        TagPostMapping tpm
    JOIN
        RecentPosts rp ON tpm.PostId = rp.PostId
    GROUP BY
        tpm.PopularTag
)

SELECT
    *,
    DENSE_RANK() OVER (ORDER BY RelatedPostCount DESC) AS TagPopularityRank
FROM
    FinalResults
ORDER BY
    RelatedPostCount DESC;
