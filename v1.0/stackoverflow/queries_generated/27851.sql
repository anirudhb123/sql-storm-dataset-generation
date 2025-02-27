WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetail AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        us.DisplayName AS AuthorName,
        us.Reputation AS AuthorReputation,
        us.QuestionsAsked,
        us.TotalViews,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.AuthorName,
    pd.AuthorReputation,
    pd.QuestionsAsked,
    pd.TotalViews,
    pd.GoldBadges,
    pd.SilverBadges,
    pd.BronzeBadges
FROM 
    PostDetail pd
WHERE 
    pd.CommentCount >= 5 -- filtering for posts with significant comments
ORDER BY 
    pd.UpVotes DESC, pd.ViewCount DESC --Ordering by popularity
LIMIT 10; -- Limiting to top 10 results
