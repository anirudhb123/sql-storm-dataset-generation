WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        U.DisplayName AS Author,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id 
            AND v.VoteTypeId = 2 -- UpMod
        ), 0) AS Upvotes,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id 
            AND v.VoteTypeId = 3 -- DownMod
        ), 0) AS Downvotes,
        (
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE
        p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        P.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts P ON ph.PostId = P.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
FilteredPosts AS (
    SELECT 
        rp.Title,
        rp.PostId,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Upvotes,
        rp.Downvotes,
        rp.CommentCount,
        COALESCE(cp.Comment, 'Not closed') AS CloseComment,
        COALESCE(cp.UserDisplayName, 'N/A') AS CloseUser
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank <= 5 -- Get top 5 posts per type
)
SELECT 
    p.*,
    (p.Upvotes - p.Downvotes) AS NetVotes, -- Calculate net votes
    CASE 
        WHEN p.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments' 
    END AS CommentStatus,
    CONCAT('Closed Comment: ', p.CloseComment, ' by ', p.CloseUser) AS CloseDetails
FROM 
    FilteredPosts p
WHERE 
    p.NetVotes > 0 -- Only include posts with net positive votes
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
