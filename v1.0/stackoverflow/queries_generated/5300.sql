WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVotes AS (
    SELECT 
        v.PostId, 
        v.VoteTypeId, 
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),
VoteSummary AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN pv.VoteCount ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN pv.VoteCount ELSE 0 END) AS DownVotes
    FROM 
        PostVotes pv
    GROUP BY 
        pv.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    us.DisplayName AS AuthorName,
    us.Reputation AS AuthorReputation,
    us.BadgeCount AS AuthorBadgeCount,
    vs.UpVotes,
    vs.DownVotes
FROM 
    TopPosts tp
JOIN 
    Users us ON tp.OwnerUserId = us.Id
LEFT JOIN 
    VoteSummary vs ON tp.PostId = vs.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
