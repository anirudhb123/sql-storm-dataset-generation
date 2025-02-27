WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        p.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Focusing on Questions and Answers
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        Score, 
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostVoteSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes 
    WHERE 
        PostId IN (SELECT PostId FROM TopRankedPosts)
    GROUP BY 
        PostId
)
SELECT 
    trp.PostId, 
    trp.Title, 
    trp.OwnerDisplayName, 
    trp.Score, 
    pvs.UpVotes, 
    pvs.DownVotes, 
    pvs.TotalVotes,
    COALESCE(ROUND(100.0 * pvs.UpVotes / NULLIF(pvs.TotalVotes, 0), 2), 0) AS UpvotePercentage
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostVoteSummary pvs ON trp.PostId = pvs.PostId
ORDER BY 
    trp.Score DESC, 
    trp.PostId;
