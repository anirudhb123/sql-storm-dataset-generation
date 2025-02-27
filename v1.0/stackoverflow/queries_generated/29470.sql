WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Only Questions
      AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Last year
),
MostActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    JOIN Comments c ON u.Id = c.UserId
    JOIN Posts p ON c.PostId = p.Id
    WHERE p.PostTypeId = 1 -- Only Questions
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(c.Id) > 5 -- Active users with more than 5 comments
),
PopularTags AS (
    SELECT
        T.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags T
    JOIN Posts p ON p.Tags LIKE '%' + T.TagName + '%'
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10 -- Top 10 popular tags
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    mu.DisplayName AS MostActiveUser,
    mu.PostCount AS UserPostCount,
    pt.TagName AS PopularTag
FROM RankedPosts rp
LEFT JOIN MostActiveUsers mu ON mu.PostCount > 0
LEFT JOIN PopularTags pt ON rp.Tags LIKE '%' + pt.TagName + '%'
WHERE rp.TagRank <= 3 -- Top 3 ranked posts per tag
ORDER BY rp.CreationDate DESC, rp.Score DESC;
