
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        u.Reputation,
        COALESCE(NULLIF(p.ClosedDate, '1900-01-01'), NULL) AS ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.Id, u.DisplayName, u.Reputation, p.Title, p.Body, p.ClosedDate
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Reputation,
        rp.ClosedDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.RecentPostRank = 1 
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),
TagStatistics AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', numbers.n), '<>', -1)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount
    FROM 
        TagStatistics
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Reputation,
    TOPU.DisplayName AS TopUserDisplayName,
    TOPU.TotalPosts AS TopUserPosts,
    T.Tag AS PopularTag,
    T.TagCount AS PopularTagCount
FROM 
    RecentPosts rp
JOIN 
    TopUsers TOPU ON rp.OwnerDisplayName = TOPU.DisplayName
JOIN 
    TopTags T ON rp.Title LIKE CONCAT('%', T.Tag, '%')
ORDER BY 
    rp.Reputation DESC, 
    rp.CommentCount DESC;
