WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.AnswerCount, p.ViewCount, p.Score
),

TopUserPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.AnswerCount,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS UserName,
        u.Reputation AS UserReputation
    FROM RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE rp.Rank = 1  -- Select only the latest post per user
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews 
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
    ORDER BY TotalViews DESC
    LIMIT 10  -- Limit to top 10 tags by view count
)

SELECT 
    utp.PostId,
    utp.Title,
    utp.CreationDate,
    utp.AnswerCount,
    utp.ViewCount,
    utp.Score,
    utp.UserName,
    utp.UserReputation,
    pt.TagName AS PopularTag,
    pt.PostsCount,
    pt.TotalViews
FROM TopUserPosts utp
JOIN PopularTags pt ON utp.PostId IN (
    SELECT p.Id
    FROM Posts p
    WHERE p.Tags LIKE CONCAT('%', pt.TagName, '%')
)
ORDER BY utp.UserReputation DESC, utp.ViewCount DESC;
