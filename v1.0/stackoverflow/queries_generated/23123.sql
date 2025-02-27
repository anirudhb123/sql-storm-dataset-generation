WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId AS CloserId,
        ph.CreationDate AS CloseDate,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::INT = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(unnest(string_to_array(p.Tags, ','))) AS Tag
    FROM 
        Posts p
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Rank,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.OwnerName,
    COALESCE(cp.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(cp.CloseReasons, 'N/A') AS CloseReasons,
    STRING_AGG(DISTINCT pt.Tag, ', ') AS PostTags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    (
        rp.Rank = 1 OR (rp.Rank > 1 AND rp.UpVotes > 5)
    )
    AND (COALESCE(cp.CloseReasonCount, 0) < 3 OR cp.CloseDate IS NULL)
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, 
    rp.Score, rp.Rank, rp.CommentCount, 
    rp.UpVotes, rp.DownVotes, rp.OwnerName, 
    cp.CloseDate, cp.CloseReasonCount, cp.CloseReasons
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 100;
