WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Filter for Questions
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UniqueVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 0 AND rp.UniqueVoteCount > 5 -- Filter for popular posts
),
TopQuestions AS (
    SELECT 
        fp.*,
        ROW_NUMBER() OVER (ORDER BY fp.CommentCount DESC) AS RankByComments
    FROM 
        FilteredPosts fp
    WHERE 
        fp.CommentCount > 0 -- Only include posts that have comments
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.CommentCount,
    tq.UniqueVoteCount,
    tq.RankByComments AS CommentRank,
    (SELECT 
        STRING_AGG(t.TagName, ', ') 
     FROM 
        Tags t 
     WHERE 
        t.Id IN (
            SELECT 
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) 
            FROM Posts p 
            WHERE p.Id = tq.PostId)
    ) AS AssociatedTags
FROM 
    TopQuestions tq
WHERE 
    tq.RankByComments <= 10; -- Get top 10 questions by comment count
