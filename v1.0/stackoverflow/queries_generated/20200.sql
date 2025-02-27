WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Filtering for upvotes and downvotes
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.VoteCount,
        rp.CommentCount,
        RANK() OVER (PARTITION BY CASE WHEN rp.PostTypeId = 1 THEN 'Question' ELSE 'Answer' END ORDER BY rp.Score DESC) AS ScoreRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT u.Id) AS UserCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    CASE 
        WHEN up.UserCount > 1 THEN 'Active User'
        ELSE 'New User'
    END AS UserType,
    COALESCE(tp.VoteCount, 0) AS VoteCount,
    COALESCE(tp.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN tp.ScoreRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank
FROM 
    TopPosts tp
JOIN 
    UserStatistics up ON tp.PostId = up.UserId
WHERE 
    tp.Score >= (
        SELECT 
            AVG(Score) 
        FROM 
            TopPosts 
        WHERE 
            ScoreRank <= 5
    )
ORDER BY 
    tp.Score DESC,
    up.GoldBadges DESC
LIMIT 100;

-- Additional queries to benchmark performance based on joins, ranking, and aggregates
WITH VoteDistribution AS (
    SELECT 
        VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        VoteTypeId
),
PostWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(vd.VoteCount, 0) AS VoteCount,
        CASE 
            WHEN vd.VoteCount > 0 THEN 'Voted'
            ELSE 'Not Voted'
        END AS VoteStatus
    FROM 
        Posts p
    LEFT JOIN 
        VoteDistribution vd ON p.Id = vd.PostId
)
SELECT 
    p.Title,
    p.VoteCount,
    CASE 
        WHEN p.VoteStatus = 'Voted' THEN 'Active Engagement'
        ELSE 'Lack of Engagement'
    END AS EngagementType
FROM 
    PostWithVotes p
WHERE 
    p.VoteCount < (
        SELECT 
            AVG(VoteCount) 
        FROM 
            PostWithVotes
    )
ORDER BY 
    p.VoteCount ASC;
