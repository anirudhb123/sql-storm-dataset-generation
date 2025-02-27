WITH RECURSIVE PostAncestors AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        pa.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostAncestors pa ON p.ParentId = pa.PostId
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.LastActivityDate,
        COALESCE(p.Body, '') AS Body,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName, Id FROM Posts) AS t ON t.Id = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.Body, p.LastActivityDate
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopVotedPosts AS (
    SELECT 
        pd.*,
        ups.UserId,
        ups.DisplayName
    FROM 
        PostDetails pd
    LEFT JOIN 
        UserPostStats ups ON pd.OwnerUserId = ups.UserId
    WHERE 
        pd.Score > 10
    ORDER BY 
        pd.Score DESC
    LIMIT 10
)
SELECT 
    t.TopicId, 
    p.Title, 
    p.Score, 
    p.ViewCount, 
    p.CreationDate, 
    u.DisplayName,
    p.Tags,
    COALESCE(pa.Level, 0) AS AncestorLevel
FROM
    TopVotedPosts p
LEFT JOIN 
    PostAncestors pa ON p.PostId = pa.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.Body NOT LIKE '%spam%'
    AND p.CommentCount > 0
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC;

