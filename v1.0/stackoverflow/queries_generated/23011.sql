WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, -- Count Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes, -- Count Downvotes
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' -- Only consider recent posts
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Rank = 1 THEN 'Best Post'
            WHEN rp.CommentCount > 5 THEN 'Popular Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3 -- Top 3 for each post type
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        tp.PostCategory,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges, -- Count Gold Badges
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges, -- Count Silver Badges
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges  -- Count Bronze Badges
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON b.UserId IN (
            SELECT DISTINCT OwnerUserId 
            FROM Posts 
            WHERE Id = tp.PostId
        )
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.CommentCount, tp.UpVotes, tp.DownVotes, tp.PostCategory
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.PostCategory,
    (pd.UpVotes - pd.DownVotes) AS NetVotes,
    CASE 
        WHEN pd.NetVotes > 0 THEN 'Positive' 
        WHEN pd.NetVotes < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment,
    pd.GoldBadges + pd.SilverBadges + pd.BronzeBadges AS TotalBadges,
    ROW_NUMBER() OVER (ORDER BY pd.NetVotes DESC) AS PostRank
FROM 
    PostDetails pd
WHERE 
    pd.TotalBadges > 0 -- Only select posts with badges
ORDER BY 
    pd.NetVotes DESC, pd.CreationDate ASC
LIMIT 10; -- Limit to top 10
