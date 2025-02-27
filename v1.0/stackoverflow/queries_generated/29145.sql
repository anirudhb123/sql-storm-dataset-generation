WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_ids ON tag_ids IS NOT NULL
    LEFT JOIN 
        Tags t ON t.Id = tag_ids::int
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.CreationDate, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(p.AnswerCount) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 -- Filter for highly reputed users
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        ua.UserId,
        ua.DisplayName AS OwnerDisplayName,
        rp.RankByViews,
        ua.BadgeCount,
        ua.CommentCount,
        ua.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.OwnerUserId = ua.UserId
)
SELECT 
    p.PostId,
    p.Title,
    p.Tags,
    p.OwnerDisplayName,
    p.RankByViews,
    p.BadgeCount,
    p.CommentCount,
    p.AnswerCount
FROM 
    PostDetails p
WHERE 
    p.RankByViews <= 5 -- Top 5 posts by views per user
ORDER BY 
    p.OwnerDisplayName, p.RankByViews;
