WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        ur.TotalBadges,
        ur.TotalBounty,
        ur.TotalUpvotes,
        CASE 
            WHEN ur.Reputation IS NULL THEN 'Unknown User'
            ELSE ur.Reputation::text
        END AS UserReputation,
        CASE 
            WHEN ur.TotalBadges > 10 THEN 'High Badge Owner'
            WHEN ur.TotalBadges BETWEEN 5 AND 10 THEN 'Moderate Badge Owner'
            ELSE 'Low/No Badges'
        END AS BadgeStatus,
        STRING_AGG(DISTINCT rp.TagList, ', ') AS AllTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.CommentCount, ur.TotalBadges, ur.TotalBounty, ur.TotalUpvotes, ur.Reputation
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.Score,
    cs.CommentCount,
    cs.UserReputation,
    cs.BadgeStatus,
    CASE 
        WHEN cs.TotalBounty >= 100 THEN 'High Bounty' 
        WHEN cs.TotalBounty BETWEEN 50 AND 99 THEN 'Moderate Bounty' 
        ELSE 'Low Bounty' 
    END AS BountyStatus
FROM 
    CombinedStats cs
WHERE 
    cs.Score IS NOT NULL
    AND cs.CommentCount > 0
    AND (cs.UserReputation::int IS NULL OR cs.UserReputation::int >= 100)
ORDER BY 
    cs.Score DESC, cs.CommentCount DESC;
This SQL query performs a series of transformations and aggregations on posts, users, and their interactions while utilizing CTEs, window functions, string manipulation, and conditional logic to achieve a comprehensive performance benchmarking report. It explores the connections between post performance, user activity, and reputation, filtering out specifics while highlighting potentially high-visibility contributions to a community knowledge base.
