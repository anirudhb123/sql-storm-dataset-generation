WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.vote_count, 0) AS UpvoteCount,
        COALESCE(c.comment_count, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankWithinUser
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS vote_count
        FROM Votes
        WHERE VoteTypeId = 2  -- Upvote
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS comment_count
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1  -- Only questions
),
FilteredPosts AS (
    SELECT 
        p.*,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.RankWithinUser <= 3  -- Get top 3 questions per user
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ht.Name AS HistoryType,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Only closed and reopened posts
),
AggregateData AS (
    SELECT 
        fp.PostId,
        COUNT(c.Id) AS TotalComments,
        MAX(fp.OwnerReputation) AS MaxReputation,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(fp.Tags, ',')) AS TagName) t ON TRUE
    GROUP BY 
        fp.PostId
)
SELECT 
    ad.PostId,
    fp.Title,
    fp.CreationDate,
    fp.UpvoteCount,
    ad.TotalComments,
    ad.Tags,
    COALESCE(ch.HistoryType, 'None') AS ClosureHistory,
    COALESCE(ch.CreationDate, 'N/A') AS ClosureDate
FROM 
    AggregateData ad
LEFT JOIN 
    ClosedPostHistory ch ON ad.PostId = ch.PostId
JOIN 
    FilteredPosts fp ON ad.PostId = fp.PostId
ORDER BY 
    fp.Score DESC, ad.TotalComments DESC;

