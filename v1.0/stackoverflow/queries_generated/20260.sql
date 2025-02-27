WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY u.Reputation DESC) AS Rnk
    FROM 
        Users u
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.HistoryCount,
        COALESCE(P.ClosedDate, '1970-01-01 00:00:00'::timestamp) AS ClosedDate,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
             p.Id,
             COUNT(ph.Id) as HistoryCount
         FROM 
             PostHistory ph 
         JOIN 
             Posts p ON ph.PostId = p.Id
         GROUP BY 
             p.Id) AS P ON p.Id = P.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.ViewCount, p.AcceptedAnswerId, P.HistoryCount, P.ClosedDate
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    rpa.PostId,
    rpa.Title,
    rpa.ViewCount,
    rpa.CommentsCount,
    rpa.UpvoteCount,
    rpa.DownvoteCount,
    tt.TagName,
    rpa.LastEditDate,
    CASE 
        WHEN rpa.AcceptedAnswerId IS NOT NULL AND rpa.AcceptedAnswerId > 0 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus,
    CASE 
        WHEN rpa.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedUsers ru
JOIN 
    RecentPostActivity rpa ON ru.UserId = rpa.OwnerUserId 
JOIN 
    TopTags tt ON tt.TagName IN (SELECT unnest(string_to_array(rpa.Title, ' '))::text)
WHERE 
    ru.Rnk <= 3
ORDER BY 
    ru.Reputation DESC,
    rpa.ViewCount DESC;
