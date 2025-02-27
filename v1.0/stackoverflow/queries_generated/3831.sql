WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS Content,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.Body, p.OwnerUserId
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT r.PostId) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts r ON u.Id = r.OwnerUserId AND r.PostTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    R.*,
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.AnswerCount
FROM 
    RankedPosts R
JOIN 
    UserStats U ON R.PostRank = 1
ORDER BY 
    R.Score DESC, 
    U.Reputation DESC
LIMIT 50;
