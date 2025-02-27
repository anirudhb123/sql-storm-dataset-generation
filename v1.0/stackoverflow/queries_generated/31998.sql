WITH RecursiveTagCounts AS (
    SELECT t.Id AS TagId, t.TagName, COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName

    UNION ALL

    SELECT tt.Id AS TagId, tt.TagName, COUNT(tp.Id) AS PostCount
    FROM Tags tt
    JOIN Posts tp ON tp.Tags LIKE '%' || tt.TagName || '%'
    JOIN RecursiveTagCounts rtc ON rtc.TagId = tt.Id
    WHERE rtc.PostCount > 0

    GROUP BY tt.Id, tt.TagName
),
PostVotes AS (
    SELECT PostId,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1
                    WHEN VoteTypeId = 3 THEN -1
                    ELSE 0 END) AS NetVotes
    FROM Votes
    GROUP BY PostId
),
RecentPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.OwnerUserId,
           pv.NetVotes,
           ROW_NUMBER() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN PostVotes pv ON p.Id = pv.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostsCount,
           SUM(b.Class) AS TotalBadgeScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(DISTINCT p.Id) > 0 -- Users who have posted at least once
),
FinalResults AS (
    SELECT rp.PostId,
           rp.Title,
           rp.CreationDate,
           rp.NetVotes,
           au.DisplayName AS Author,
           rtc.PostCount AS RelatedTagCount
    FROM RecentPosts rp
    JOIN ActiveUsers au ON rp.OwnerUserId = au.UserId
    LEFT JOIN RecursiveTagCounts rtc ON rtc.TagId = ANY(ARRAY(SELECT UNNEST(STRING_TO_ARRAY(rp.Title, ' ')))) 
WHERE rp.Rank <= 10  -- Top 10 recent posts per year
)
SELECT FR.PostId,
       FR.Title,
       FR.CreationDate,
       FR.NetVotes,
       FR.Author,
       COALESCE(FR.RelatedTagCount, 0) AS RelatedTagCount
FROM FinalResults FR
ORDER BY FR.CreationDate DESC;
