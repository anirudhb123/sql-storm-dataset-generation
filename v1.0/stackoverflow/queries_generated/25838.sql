WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.AssociatedTags,
    u.BadgeCount,
    u.Badges,
    u.UserPostRank
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    p.UserPostRank <= 5 -- Get top 5 posts per user
ORDER BY 
    p.CreationDate DESC;
This query creates two common table expressions (CTEs): `RankedPosts`, which ranks posts based on the user and retrieves relevant statistics, and `UserBadges`, which counts badges held by users. The final selection pulls data from both CTEs, providing insights into the top posts and their authors, showcasing a combination of string processing (in aggregating tags and badges) and various other statistics.
