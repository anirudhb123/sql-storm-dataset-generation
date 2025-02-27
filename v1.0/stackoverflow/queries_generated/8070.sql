WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC, SUM(v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId -- Joining to count answers
    LEFT JOIN 
        Comments c ON p.Id = c.PostId -- Joining to count comments
    LEFT JOIN 
        Votes v ON p.Id = v.PostId -- Joining to count votes
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.QuestionCount,
    us.AnswerCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    rp.Rank <= 5 -- Top 5 ranked posts per user
ORDER BY 
    us.Reputation DESC, rp.UpVotes DESC;
