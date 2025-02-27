WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND u.Reputation > 1000
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.UserId) AS UniqueVoters
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CloseVotes AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVotesCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COALESCE(cv.CloseVotesCount, 0) AS TotalCloseVotes,
        ub.BadgeCount,
        ub.BadgeNames,
        CASE 
            WHEN cv.CloseVotesCount > 0 THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes v ON rp.PostId = v.PostId
    LEFT JOIN 
        CloseVotes cv ON rp.PostId = cv.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerDisplayName = ub.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    OwnerDisplayName,
    TotalUpVotes,
    TotalDownVotes,
    TotalCloseVotes,
    BadgeCount,
    BadgeNames,
    PostStatus
FROM 
    FinalResults
WHERE 
    Rank <= 5
ORDER BY 
    CreationDate DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation of the Query:

1. **Common Table Expressions (CTEs):**
   - `RankedPosts`: Ranks posts based on creation date for each post type (questions and answers) by users with reputation over 1000.
   - `UserBadges`: Counts badges per user and concatenates badge names, which provides insights into user achievements.
   - `PostVotes`: Aggregates the vote counts (upvotes and downvotes) for each post and counts unique voters.
   - `CloseVotes`: Counts the number of times each post has been voted to close.

2. **Final Selection:**
   - Combines results from the CTEs, calculates total upvotes, downvotes, close votes, and assesses post status (open/closed).
  
3. **Filtering and Ordering:**
   - Filters to show top 5 most recent posts per post type and limits the final output to 10 results, displaying them in descending order of creation date.

4. **NULL Handling and Aggregations:**
   - Uses `COALESCE` to handle potential NULLs in vote counts and badges effectively.

5. **String Aggregation:**
   - Combines badge names into a single string with the `STRING_AGG` function.
