WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Upvotes
        SUM(v.VoteTypeId = 3) AS DownVoteCount,  -- Downvotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.RecentPostRank <= 5  -- Only consider the 5 most recent posts by each user
)
SELECT 
    fp.OwnerDisplayName,
    COUNT(fp.PostId) AS TotalPosts,
    SUM(fp.CommentCount) AS TotalComments,
    AVG(fp.UpVoteCount) AS AverageUpVotes,
    AVG(fp.DownVoteCount) AS AverageDownVotes,
    STRING_AGG(DISTINCT TRIM(BOTH '<>' FROM unnest(string_to_array(fp.Tags, '>'))), ', ') AS UniqueTags,
    STRING_AGG(DISTINCT fp.Sentiment, ', ') AS UniqueSentiments
FROM 
    FilteredPosts fp
GROUP BY 
    fp.OwnerDisplayName
HAVING 
    COUNT(fp.PostId) > 0
ORDER BY 
    TotalPosts DESC;
