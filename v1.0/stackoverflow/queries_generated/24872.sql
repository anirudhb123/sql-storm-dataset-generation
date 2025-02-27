WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, pt.Name
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(p.CreationDate) AS LastActivePostDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    GROUP BY 
        u.Id
    HAVING 
        MAX(p.CreationDate) >= NOW() - INTERVAL '6 months'
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.PostTypeId, 
        rp.Score, 
        rp.ViewCount, 
        au.UserId,
        au.DisplayName AS UserDisplayName,
        au.Reputation,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    INNER JOIN 
        ActiveUsers au ON rp.RankByScore <= 10
    WHERE 
        rp.Score IS NOT NULL
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.PostTypeId,
    tp.Score,
    tp.ViewCount,
    STRING_AGG(DISTINCT t.TagName) AS Tags,
    tp.UserDisplayName,
    tp.Reputation,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    CASE 
        WHEN tp.Score > 100 THEN 'Hot'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Warm'
        ELSE 'Cold'
    END AS PostHeat,
    (SELECT AVG(Score) FROM Posts where PostTypeId = tp.PostTypeId) AS AvgScoreByType,
    (SELECT COUNT(*) FROM Votes WHERE PostId = tp.PostId AND VoteTypeId = 2) AS TotalUpVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostsTags pt ON tp.PostId = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
GROUP BY 
    tp.PostId, tp.Title, tp.PostTypeId, tp.Score, tp.ViewCount, tp.UserDisplayName, tp.Reputation, 
    tp.CommentCount, tp.UpvoteCount, tp.DownvoteCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
