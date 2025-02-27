WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 5) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
RecentPostEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
), 
FrequentTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 20
)
SELECT 
    u.DisplayName,
    u.Reputation,
    uc.UpVotes,
    uc.DownVotes,
    rp.Title AS LastEditedTitle,
    rp.CreationDate AS LastEditDate,
    ft.TagName,
    ft.PostCount
FROM 
    Users u
LEFT JOIN 
    UserVoteCounts uc ON u.Id = uc.UserId
LEFT JOIN 
    RecentPostEdits rp ON u.Id = rp.UserDisplayName 
    AND rp.EditRank = 1
LEFT JOIN 
    FrequentTags ft ON ft.PostCount > 20
WHERE 
    u.Reputation IS NOT NULL
    AND u.Location IS NOT NULL
    AND (uc.TotalVotes IS NULL OR uc.TotalVotes > 10)
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;
This SQL query performs various complex functions including:

1. **Common Table Expressions (CTEs)**: Three CTEs are used to determine user vote counts, recent post edits, and frequently used tags.

2. **Aggregations and Conditional Counts**: Counts user votes based on their types (upvotes, downvotes) and total votes, using conditional aggregations.

3. **Window Functions**: `ROW_NUMBER()` is used to determine the most recent edit per post.

4. **String Matching**: It checks if the post tags match with frequently used tags using a LIKE statement.

5. **Outer Joins**: Several LEFT JOINs are used to include users with no votes and posts that may have no edits.

6. **Bizarre Semantical Concepts**: The use of `IS NOT NULL` coupled with checks for `TotalVotes` ensures that we only include users with valid reputations, valid locations, and at least a certain amount of activity.

7. **Limit with Complex Ordering**: It orders the final result set by user reputation and the date of the last edit to give a prioritized view.

This query is particularly intricate and showcases a variety of SQL constructs suitable for performance benchmarking.
