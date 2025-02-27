WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),

UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 5000
),

PostDetails AS (
    SELECT
        rp.Title,
        tu.DisplayName,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.Id
)

SELECT 
    pd.DisplayName AS Author,
    pd.Title AS PostTitle,
    pd.CreationDate,
    pd.Score,
    pd.AnswerCount,
    pd.UpVotes - pd.DownVotes AS NetVotes,
    (CASE 
        WHEN pd.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post' 
    END) AS PostType
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 3
ORDER BY 
    pd.Score DESC, pd.CreationDate ASC
LIMIT 
    10;

-- Include posts that are tagged as both question and wiki
UNION ALL

SELECT 
    'Community' AS Author,
    'Tag Wiki Post' AS PostTitle,
    MIN(p.CreationDate) AS CreationDate,
    SUM(p.Score) AS TotalScore,
    COUNT(*) AS CountPosts,
    0 AS UpVotes,
    0 AS DownVotes,
    'Wiki Post' AS PostType
FROM 
    Posts p
WHERE 
    p.PostTypeId IN (4, 5) 
GROUP BY 
    p.Tags
HAVING 
    COUNT(*) > 1
ORDER BY 
    TotalScore DESC
LIMIT 
    5;
