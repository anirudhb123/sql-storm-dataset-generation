WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS OwnPosts,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL AND p.PostTypeId = 1 THEN 1 ELSE 0 END) AS OwnQuestions,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL AND p.PostTypeId = 2 THEN 1 ELSE 0 END) AS OwnAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViews,
    us.DisplayName AS PostOwner,
    us.Reputation AS OwnerReputation,
    us.BadgeCount AS OwnerBadges,
    tp.AnswerCount AS Answers,
    tp.UpVotes AS UpVotes,
    tp.DownVotes AS DownVotes
FROM 
    TopPosts tp
JOIN 
    Users us ON tp.OwnerUserId = us.Id
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
