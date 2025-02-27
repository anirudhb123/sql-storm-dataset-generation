WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.Tags,
        p.AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RecentActivity AS (
    SELECT 
        uh.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Users uh ON v.UserId = uh.Id
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        uh.UserId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        ra.UserId,
        ra.VoteCount,
        ra.AcceptedVotes,
        ra.UpVotes,
        ra.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
    WHERE 
        rp.ViewRank <= 5 
        OR ra.AcceptedVotes IS NOT NULL
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    COALESCE(pd.VoteCount, 0) AS UserVotes,
    COALESCE(pd.AcceptedVotes, 0) AS AcceptedVotes,
    COALESCE(pd.UpVotes, 0) AS UpVotes,
    COALESCE(pd.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN pd.Score > 50 THEN 'Highly Rated'
        WHEN pd.Score IS NULL THEN 'No Score'
        ELSE 'Moderate or Low'
    END AS PostRating,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    UNNEST(string_to_array(pd.Tags, '<>')) AS t(TagName) ON true
GROUP BY 
    pd.PostId, pd.Title, pd.ViewCount, pd.Score, pd.CommentCount, 
    pd.VoteCount, pd.AcceptedVotes, pd.UpVotes, pd.DownVotes
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC
LIMIT 10;
