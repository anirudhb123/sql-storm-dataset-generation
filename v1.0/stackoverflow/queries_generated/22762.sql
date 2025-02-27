WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        ARRAY_AGG(t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),

MaxScores AS (
    SELECT 
        PostTypeId,
        MAX(Score) AS MaxPostScore
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),

CommentsWithVotes AS (
    SELECT 
        c.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount, -- Count of upvotes
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount, -- Count of downvotes
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    LEFT JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.PostRank,
    cm.TotalComments,
    cm.UpVotesCount,
    cm.DownVotesCount,
    COALESCE(MAX(sc.MaxPostScore), 0) AS MaxScoreForType,
    CASE 
        WHEN rp.Score > COALESCE(MAX(sc.MaxPostScore), 0) THEN 'Above Average'
        WHEN rp.Score = COALESCE(MAX(sc.MaxPostScore), 0) THEN 'Average'
        ELSE 'Below Average'
    END AS ScoreComparison,
    STRING_AGG(DISTINCT t.TagName, ', ') AS CombinedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentsWithVotes cm ON rp.PostId = cm.PostId
LEFT JOIN 
    MaxScores sc ON rp.PostTypeId = sc.PostTypeId
LEFT JOIN 
    Tags t ON t.TagName = ANY(rp.TagsArray)
WHERE 
    rp.PostRank <= 5 -- Top 5 posts per category
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.PostRank, cm.TotalComments, cm.UpVotesCount, cm.DownVotesCount
ORDER BY 
    rp.PostRank, rp.PostId;
