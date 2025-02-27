WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.CreationDate, p.PostTypeId, p.AcceptedAnswerId
), RecentBadges AS (
    SELECT 
        B.UserId,
        ARRAY_AGG(B.Name ORDER BY B.Date DESC) AS RecentBadgeNames
    FROM 
        Badges B
    WHERE 
        B.Date >= NOW() - INTERVAL '1 year'
    GROUP BY 
        B.UserId
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        COALESCE(rb.RecentBadgeNames, '{}') AS RecentBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentBadges rb ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN array_length(tp.RecentBadges, 1) > 0 THEN 
            'Recent badges: ' || array_to_string(tp.RecentBadges, ', ')
        ELSE 
            'No recent badges for the owner'
    END AS BadgeInfo,
    CASE 
        WHEN tp.UpVoteCount - tp.DownVoteCount < 0 THEN 
            'Flawed'
        WHEN tp.UpVoteCount = tp.DownVoteCount THEN 
            'Neutral'
        ELSE 
            'Accepted'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVoteCount DESC NULLS LAST;

This SQL query performs the following tasks:

1. **RankedPosts CTE**: It ranks posts based on their `Score` within each `PostTypeId` while counting associated comments and up/down votes.

2. **RecentBadges CTE**: It collects recent badges earned by users in the past year into an array for each user.

3. **TopPosts CTE**: It joins the ranked posts with the recent badges based on accepted answer criteria and filters to get the top 10 posts.

4. **Final SELECT**: The final output presents the posts with their titles, creation dates, associated user display names, comment counts, upvote counts, downvote counts, and a status message based on the vote differences. The badge information is presented with string expressions highlighting whether the user has earned any recent badges.

This query combines multiple SQL constructs, such as CTEs, string expressions, complex predicates, and filtering logic, making it suitable for performance benchmarking and exploring SQL semantics.
