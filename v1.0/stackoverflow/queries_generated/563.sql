WITH UserPostStats AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.CreationDate IS NOT NULL) AS VoteCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        VoteCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY PostCount DESC, VoteCount DESC) AS Rank
    FROM 
        UserPostStats
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.PostCount,
    r.AnswerCount,
    r.VoteCount,
    r.GoldBadges,
    r.SilverBadges,
    r.BronzeBadges,
    json_agg(json_build_object('PostId', rp.PostId, 'Title', rp.Title, 'CreationDate', rp.CreationDate, 'Author', rp.Author, 'Score', rp.Score, 'Tags', rp.Tags)) AS RecentPosts
FROM 
    RankedUsers r
LEFT JOIN 
    RecentPosts rp ON r.UserId = rp.Author
WHERE 
    r.Rank <= 10
GROUP BY 
    r.UserId, r.DisplayName, r.PostCount, r.AnswerCount, r.VoteCount, r.GoldBadges, r.SilverBadges, r.BronzeBadges
ORDER BY 
    r.PostCount DESC, r.VoteCount DESC;
