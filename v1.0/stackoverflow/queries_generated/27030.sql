WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2) ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Filter for Questions
      AND 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
),
TopRepliedToPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.TagRank = 1 -- Only consider top post per tag
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName
    HAVING 
        COUNT(c.Id) > 5 -- Only keep posts with more than 5 comments
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Filter for users with a specific reputation
),
PopularBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(b.Id) >= 3 -- Users with at least 3 badges
)

SELECT 
    trp.Title,
    trp.OwnerDisplayName,
    trp.CommentCount,
    ur.DisplayName AS ActiveUserDisplayName,
    ur.Reputation,
    pb.BadgeCount
FROM 
    TopRepliedToPosts trp
JOIN 
    UserReputation ur ON trp.OwnerDisplayName = ur.DisplayName
LEFT JOIN 
    PopularBadges pb ON ur.UserId = pb.UserId
ORDER BY 
    trp.CommentCount DESC, 
    ur.Reputation DESC
OPTION (MAXDOP 4); -- Option to parallelize query for performance benchmarking
