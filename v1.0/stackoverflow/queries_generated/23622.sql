WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), 
CloseReasons AS (
    SELECT 
        ph.PostId,
        jsonb_agg(cr.Name) AS CloseReasonNames,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
), 
PostStats AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2)::int AS UpVoteCount,
        SUM(v.VoteTypeId = 3)::int AS DownVoteCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        COALESCE(cr.CloseReasonNames, '[]'::jsonb) AS CloseReasons,
        COALESCE(cr.CloseReasonCount, 0) AS CloseReasonCount,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        CASE 
            WHEN COALESCE(ps.UpVoteCount, 0) = 0 THEN NULL 
            ELSE (ps.UpVoteCount::float / NULLIF(ps.UpVoteCount + ps.DownVoteCount, 0)) 
        END AS VoteRatio,
        CASE 
            WHEN rp.UserPostRank > 10 THEN 'Other'
            ELSE 'Top'
        END AS UserPostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CloseReasons cr ON rp.PostId = cr.PostId
    LEFT JOIN 
        PostStats ps ON rp.PostId = ps.Id
)
SELECT 
    *,
    CASE 
        WHEN Jsonb_ARRAY_LENGTH(CloseReasons) > 0 THEN 
            'This post is closed for the following reasons: ' || 
            string_agg(DISTINCT CloseReasonNames::text, ', ')
        ELSE 
            'This post is currently open.'
    END AS PostStatus
FROM 
    AggregatedData
WHERE 
    UserPostCategory = 'Top' OR CloseReasonCount > 0
ORDER BY 
    CreationDate DESC, Score DESC;
