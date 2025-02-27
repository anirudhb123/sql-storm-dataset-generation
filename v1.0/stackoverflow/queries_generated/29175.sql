WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- UpMod
        SUM(v.VoteTypeId = 3) AS DownVoteCount, -- DownMod
        SUM(v.VoteTypeId = 10) AS DeletionVotes, -- Deletion votes
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2020-01-01' AND
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate
),

FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        DeletionVotes,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    fp.Title,
    fp.Author,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.DeletionVotes,
    TO_CHAR(fp.CreationDate, 'MMMM DD, YYYY') AS FormattedCreationDate,
    CASE 
        WHEN fp.UpVoteCount > fp.DownVoteCount THEN 'Positive'
        WHEN fp.UpVoteCount < fp.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN fp.DeletionVotes > 0 THEN 'Possible Deletion'
        ELSE 'Active'
    END AS Status
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CommentCount DESC;
