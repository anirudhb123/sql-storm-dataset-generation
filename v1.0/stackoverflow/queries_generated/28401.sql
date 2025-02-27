WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        RANK() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedVotes AS (
    SELECT 
        postId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        av.UpVotes,
        av.DownVotes,
        rp.PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AggregatedVotes av ON rp.PostId = av.PostId
    WHERE 
        rp.PostRank <= 5  -- Top 5 posts per location
)
SELECT 
    TRP.Title,
    TRP.Tags,
    TRP.OwnerDisplayName,
    TRP.Score,
    TRP.UpVotes,
    TRP.DownVotes,
    TRP.CreationDate,
    (SELECT STRING_AGG(Comment, ' | ') 
     FROM Comments c 
     WHERE c.PostId = TRP.PostId) AS CommentsSummary
FROM 
    TopRankedPosts TRP
ORDER BY 
    TRP.Score DESC, 
    TRP.CreationDate DESC;
