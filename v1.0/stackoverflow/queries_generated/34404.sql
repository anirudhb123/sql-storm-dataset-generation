WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PostStatistics AS (
    SELECT
        PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        ph.PostId
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVotes,
        ps.DownVotes,
        cp.FirstClosedDate,
        DATEDIFF(CURRENT_TIMESTAMP, rp.CreationDate) AS AgeInDays
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostStatistics ps ON rp.PostId = ps.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank = 1 -- Top scoring post per user
)
SELECT 
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.VoteCount,
    f.UpVotes,
    f.DownVotes,
    COALESCE(f.FirstClosedDate, 'Not Closed') AS Status,
    f.AgeInDays,
    CASE 
        WHEN f.VoteCount > 0 THEN ROUND((f.UpVotes::FLOAT / NULLIF(f.VoteCount, 0)) * 100, 2)
        ELSE 0 
    END AS UpvotePercentage
FROM 
    FinalPosts f
WHERE 
    f.AgeInDays > 30 -- Only consider posts older than 30 days
ORDER BY 
    f.UpvotePercentage DESC, f.CommentCount DESC;
