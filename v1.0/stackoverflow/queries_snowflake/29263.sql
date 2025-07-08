
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '>')) AS tag ON tag.value IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
RankedComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentsOnPost,
        LISTAGG(c.Text, ' | ') WITHIN GROUP (ORDER BY c.Id) AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges, 
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title, 
    rp.Body, 
    rp.CreationDate, 
    rp.OwnerDisplayName, 
    COALESCE(rc.CommentsOnPost, 0) AS TotalComments,
    COALESCE(rc.CommentTexts, 'No comments') AS CommentSamples,
    rp.VoteCount,
    rp.Tags,
    CASE 
        WHEN ur.TotalBadges IS NULL THEN 'No badges'
        ELSE 'Total Badges: ' || COALESCE(ur.TotalBadges, 0) || ', Average Reputation: ' || COALESCE(ur.AvgReputation, 0)
    END AS UserInsights
FROM 
    RankedPosts rp
LEFT JOIN 
    RankedComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    Users u ON rp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    UserReputation ur ON ur.UserId = u.Id
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
