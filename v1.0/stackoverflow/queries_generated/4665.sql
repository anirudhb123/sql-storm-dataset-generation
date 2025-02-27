WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ARRAY_LENGTH(string_to_array(p.Tags, '<>'), 1) AS TagCount,
        COALESCE(ph.Date, p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(inner_ph.CreationDate) 
            FROM PostHistory inner_ph 
            WHERE inner_ph.PostId = p.Id
        )
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopAuthors AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        us.UpVotes,
        us.DownVotes,
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.PostId) AS PostCount
    FROM 
        RankedPosts rp
    JOIN 
        UserScores us ON rp.OwnerUserId = us.UserId
    GROUP BY 
        u.UserId, u.DisplayName, us.UpVotes, us.DownVotes
    HAVING 
        COUNT(rp.PostId) > 5
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    ta.DisplayName,
    ta.PostCount,
    ta.TotalScore,
    (ta.UpVotes - ta.DownVotes) AS NetVotes,
    (SELECT ARRAY_AGG(DISTINCT p.Title ORDER BY p.Title)
     FROM Posts p 
     WHERE p.OwnerUserId = ta.UserId) AS RecentPosts
FROM 
    TopAuthors ta
WHERE 
    EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = ta.UserId AND b.Class = 1
    )
ORDER BY 
    ta.TotalScore DESC;
