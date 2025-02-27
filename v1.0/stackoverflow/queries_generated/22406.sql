WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        string_agg(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    GROUP BY 
        ph.PostId, ph.CreationDate
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
        tu.UserRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON cp.PostId = rp.PostId
    JOIN 
        TopUsers tu ON tu.UserId = rp.OwnerUserId
    WHERE 
        rp.Rank <= 3 -- Only consider the latest 3 posts per user
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CloseReasons,
    fp.UserRank,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive'
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN fp.CloseReasons IS NOT NULL THEN 
            'Closed Due to: ' || fp.CloseReasons
        ELSE 
            'Open'
    END AS PostStatus
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC,
    fp.UserRank;

This query constructs several Common Table Expressions (CTEs) to progressively filter and refine the dataset from the schema. Key features include:

1. **Filter by User**: It restricts to the latest three posts from each user and aggregates relevant details such as vote counts and comment counts.
2. **Close Reasons Handling**: It handles post closure by collecting close reasons via string aggregation.
3. **Ranking Users**: It ranks users based on their upvotes received across posts.
4. **Sentiment Analysis**: It provides basic sentiment information based on the counts of upvotes and downvotes.
5. **Dynamic Post Status**: It adjusts the status message based on whether the post has close reasons or not. 

This query showcases various SQL constructs, including window functions, outer joins, CTEs, and dynamic string expressions, all while considering NULL logic gracefully.
